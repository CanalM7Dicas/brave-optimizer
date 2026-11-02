# Brave Optimizer

Automacao para Windows que aplica ajustes especificos ao Brave. O modo completo se aproxima do fluxo mostrado no [video do Canal M7 Dicas](https://www.youtube.com/watch?v=QocKlUfe2sQ): configura opcoes internas, aplica ajustes opcionais no Registro e limpa caches. O Brave precisa estar fechado. A ferramenta nao encerra suas janelas nem instala outros programas.

## Baixar

Na pagina [Releases](../../releases), baixe `Brave-Optimizer.zip` da versao mais recente. Extraia e mantenha `installer.bat` e `optimize_brave.ps1` juntos. Execute o BAT e escolha uma opcao. O download contem somente esses dois arquivos.

## Opcoes do menu

1. **Ver alteracoes planejadas:** lista as preferencias e mostra quais politicas do Registro seriam criadas.
2. **Opcoes internas:** altera somente as preferencias especificadas, em todos os perfis locais `Default` e `Profile N`. Se uma opcao ja estiver no estado desejado, nao toca nela.
3. **Tweaks de Registro:** cria politicas para desativar Rewards, Wallet, VPN, Leo, News, metricas e apps em segundo plano; ativa aceleracao grafica e o Economizador de Memoria no nivel maximo. O Brave pode mostrar **"gerenciado pela organizacao"**. Politicas preexistentes sao preservadas.
4. **Limpar caches:** remove somente pastas de cache dos perfis locais. O Brave as recria quando necessario. Essa limpeza nao pode ser desfeita e a primeira abertura pode demorar mais.
5. **Aplicar tudo:** executa as opcoes internas, os tweaks de Registro e a limpeza de cache.
6. **Restaurar:** devolve apenas os valores que a ferramenta alterou e que ainda estao iguais aos aplicados. O cache nao pode ser restaurado.

As opcoes internas incluem a nova aba, barras e botoes extras, Leo, Containers, Speedreader, contador visual dos Escudos, avisos de fechamento, downloads e segundo plano. O preenchimento automatico da barra de endereco fica ativo apenas para **Favoritos** e **Historico de navegacao**. O contador dos Escudos e ocultado, mas o bloqueio de anuncios/rastreadores e a protecao contra impressoes digitais nao sao reduzidos. O bloqueio do Microsoft Recall permanece intocado. Mecanismos de pesquisa, extensoes, senhas, sincronizacao e permissoes de sites tambem permanecem intactos.

O nivel maximo do Economizador de Memoria pode recarregar abas inativas mais cedo. Abas que reproduzem audio ou video normalmente nao sao desativadas pelo recurso, mas o comportamento depende da versao do navegador. Se usa WhatsApp Web ou outro site que precisa continuar ativo, confira `brave://settings/performance` e adicione o site as excecoes quando necessario.

As politicas ficam em `HKCU\SOFTWARE\Policies\BraveSoftware\Brave`. Confira o resultado em `brave://policy`; se alguma politica aparecer como desconhecida na sua versao, o Brave a ignorou. A ferramenta nao substitui politicas que ja existiam no usuario ou no computador. Os registros de restauracao ficam em `%LOCALAPPDATA%\BraveOptimizer`. Nao guardam senhas nem copias permanentes do arquivo completo de preferencias.

Voce tambem pode chamar o script diretamente com `-Action Preview`, `Apply`, `Registry`, `Cache`, `All` ou `Restore`. O BAT usa `-ExecutionPolicy Bypass` apenas no processo que executa este script. Ao terminar, pressione uma tecla para fechar a janela.

Nenhuma configuracao garante um ganho fixo de RAM ou FPS. O impacto varia conforme as abas e extensoes em uso. Projeto independente, desenvolvido por [CanalM7Dicas](https://youtube.com/@CanalM7dicas), sem afiliacao ao Brave.

