# Brave Optimizer

Ferramenta para quem quer desligar recursos opcionais do Brave no Windows. Ela usa políticas do navegador para o **usuário atual** e oferece uma opção para desfazer as alterações. Não instala programas, não baixa arquivos e não precisa de permissão de administrador.

## O que muda

Ao escolher **Aplicar**, a ferramenta desliga Brave Rewards, Wallet, VPN, Leo e News. Ela só cria políticas que ainda não existem. Se uma dessas opções já foi definida por você ou pelo administrador do computador, a ferramenta a preserva.

O Brave pode mostrar a mensagem **"gerenciado pela organização"** enquanto uma política estiver ativa. Isso é o comportamento normal de configurações impostas pelo Registro. Abra `brave://policy` para conferir os valores. Reinicie o Brave quando for conveniente para aplicar ou restaurar as mudanças.

A ferramenta **não** fecha o navegador, apaga cache, altera senhas ou sincronização, muda a pesquisa padrão, mexe nas proteções contra sites perigosos nem abre uma porta de depuração. Ela não promete uma redução fixa de RAM ou melhora de FPS. Recursos opcionais desligados podem reduzir atividade em alguns casos, mas o efeito depende do uso e da versão do Brave.

## Baixar e executar

1. Abra a página [Releases](../../releases) e baixe `Brave-Optimizer.zip` da versão mais recente.
2. Extraia o ZIP. Ele contém apenas `installer.bat` e `optimize_brave.ps1`.
3. Deixe os dois arquivos juntos e execute `installer.bat`.
4. Escolha **1** para conferir as alterações, **2** para aplicar ou **3** para restaurar.

O arquivo BAT chama o PowerShell com `-ExecutionPolicy Bypass` somente nesse processo. Você também pode abrir o PowerShell e executar o script diretamente com `-Action Preview`, `-Action Apply` ou `-Action Restore`.

O registro das políticas criadas fica em `%LOCALAPPDATA%\BraveOptimizer\policy-state.json`. A opção **Restaurar** remove apenas os valores criados pela ferramenta e ainda iguais aos aplicados por ela. Ela preserva valores que outra pessoa ou programa alterou depois.

## Escopo e verificacao

As políticas são gravadas em `HKCU\SOFTWARE\Policies\BraveSoftware\Brave`. Valores definidos em `HKLM` ou já existentes em `HKCU` são preservados. Antes de aplicar, confira as escolhas na tela. Depois, veja o resultado em `brave://policy`.

Se quiser reduzir o uso de memória de abas inativas, confira o Economizador de Memória em `brave://settings/performance` e ajuste conforme seu uso. Isso fica a seu critério, especialmente se você usa música ou mensagens em segundo plano.

Projeto independente, desenvolvido por [CanalM7Dicas](https://youtube.com/@CanalM7dicas). Não é afiliado ao Brave.
